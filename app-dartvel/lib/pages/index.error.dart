// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../dartvel_client/dartvel_client.dart';

@DVFunctionalWidget()
Widget _indexPageError(BuildContext context) => DVBox.list(<Widget>[
      const DVText('Something went wrong').modifier(
        const DVModifier().fontSize(24).fontWeight(.w800),
      ),
      const DVText('The page could not load its data.'),
      const DVText('Go back').modifier(
        const DVModifier()
            .padding(12)
            .rounded(8)
            .backgroundColor(Colors.black)
            .color(Colors.white)
            .onPressed(() => Navigator.of(context).pop()),
      ),
    ]).modifier(
      const DVModifier().align(.center),
    );
