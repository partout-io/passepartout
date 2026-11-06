// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ui/extensions/app_profile.h"
#include "ui/extensions/data_helpers.h"
#include <cassert>
#include <locale>

using namespace Passepartout;
namespace {
class CommaDecimal final : public std::numpunct<char> {
protected:
    char do_decimal_point() const override {
        return ',';
    }
};
}
int main() {
    assert(FormatDataUnit(-1) == "0B");
    assert(FormatDataUnit(0) == "0B");
    assert(FormatDataUnit(1023) == "1023B");
    assert(FormatDataUnit(1024) == "1kB");
    assert(FormatDataUnit(104857) == "0.10MB");
    assert(FormatDataUnit(548575) == "0.52MB");
    assert(FormatDataUnit(1048575) == "1.00MB");
    // Match Android's fixed decimal locale even on comma-decimal systems.
    const auto previous = std::locale();
    std::locale::global(std::locale(previous, new CommaDecimal));
    Models::ProfileTransfer transfer{};
    transfer.received = 5LL * 1024 * 1024 * 1024;
    transfer.sent = 548575;
    assert(TransferText(transfer) == "\xe2\x86\x93" "5.00GB \xe2\x86\x91" "0.52MB");
    std::locale::global(previous);
}
