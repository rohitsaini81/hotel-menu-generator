import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;
import 'package:google_sign_in_web/web_only.dart'
    show
        GSIButtonConfiguration,
        GSIButtonLogoAlignment,
        GSIButtonShape,
        GSIButtonSize,
        GSIButtonText,
        GSIButtonTheme,
        GSIButtonType;

class GoogleSignInWebButton extends StatelessWidget {
  const GoogleSignInWebButton({super.key, this.isBusy = false});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isBusy,
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: gsi_web.renderButton(
          configuration: GSIButtonConfiguration(
            type: GSIButtonType.standard,
            text: GSIButtonText.continueWith,
            theme: GSIButtonTheme.outline,
            size: GSIButtonSize.large,
            shape: GSIButtonShape.pill,
            logoAlignment: GSIButtonLogoAlignment.left,
          ),
        ),
      ),
    );
  }
}
