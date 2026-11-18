// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "OnDemandView.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"
#include <algorithm>

namespace Passepartout {
OnDemandView::OnDemandView(wxWindow *parent, const Partout::Models::OnDemandModule &module)
    : ThemeDetailView(parent, Presentation::Form) {
    using namespace Partout::Models;
    auto policy = StringKey::EntitiesOnDemandPolicyAny;
    auto explanation = StringKey::ModulesOnDemandPolicyFooterAny;
    if (module.policy.value == OnDemandModulePolicy::including) {
        policy = StringKey::EntitiesOnDemandPolicyIncluding;
        explanation = StringKey::ModulesOnDemandPolicyFooterIncluding;
    } else if (module.policy.value == OnDemandModulePolicy::excluding) {
        policy = StringKey::EntitiesOnDemandPolicyExcluding;
        explanation = StringKey::ModulesOnDemandPolicyFooterExcluding;
    }
    Section(Localized(StringKey::ModulesOnDemandPolicy));
    Field(Localized(StringKey::ModulesOnDemandPolicy), Localized(policy));
    auto footer = Localized(StringKey::ModulesOnDemandPolicyFooter);
    footer.Replace("%@", Localized(explanation));
    Message(footer, TextStyle::Secondary);
    if (module.policy.value == OnDemandModulePolicy::any) {
        Finish();
        return;
    }
    Section(Localized(StringKey::GlobalNounsNetworks));
    const auto hasNetwork = [&module](OnDemandModuleOtherNetwork::eOnDemandModuleOtherNetwork type) {
        return std::any_of(module.withOtherNetworks.begin(), module.withOtherNetworks.end(),
            [type](const auto &network) {
                return network.value == type;
            });
    };
    Toggle(Localized(StringKey::ModulesOnDemandMobile), {},
        hasNetwork(OnDemandModuleOtherNetwork::mobile))->Disable();
    Toggle(Localized(StringKey::ModulesOnDemandEthernet), {},
        hasNetwork(OnDemandModuleOtherNetwork::ethernet))->Disable();
    Message(Localized(StringKey::ModulesOnDemandNetworksFooter), TextStyle::Secondary);
    Section(Strings::Unlocalized::WiFi);
    for (const auto &[ssid, enabled] : module.withSSIDs) {
        CopiableToggle(wxString::FromUTF8(ssid), enabled)->Disable();
    }
    Finish();
}
}
