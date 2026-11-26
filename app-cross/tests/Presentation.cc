// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ui/extensions/ModelsExtensions.h"
#include "ui/extensions/ModelsExtensions.h"
#include <cassert>
#include <locale>

namespace {
class CommaDecimal final : public std::numpunct<char> {
protected:
    char do_decimal_point() const override {
        return ',';
    }
};
}

using namespace Passepartout;
int main() {
    assert(DataUnits::Format(-1) == "0B");
    assert(DataUnits::Format(0) == "0B");
    assert(DataUnits::Format(1023) == "1023B");
    assert(DataUnits::Format(1024) == "1kB");
    assert(DataUnits::Format(104857) == "0.10MB");
    assert(DataUnits::Format(548575) == "0.52MB");
    assert(DataUnits::Format(1048575) == "1.00MB");
    // Respect the supplied locale instead of forcing a decimal dot.
    const auto previous = std::locale();
    std::locale::global(std::locale(previous, new CommaDecimal));
    Models::ProfileTransfer transfer{};
    transfer.received = 5LL * 1024 * 1024 * 1024;
    transfer.sent = 548575;
    assert(Profiles::TransferText(transfer) == "\xe2\x86\x93" "5,00GB \xe2\x86\x91" "0,52MB");
    std::locale::global(previous);
}
