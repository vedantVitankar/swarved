import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../models/connection_status.dart';
import '../../services/connection_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';

/// Where the server token is entered and the connection is tested.
/// The saved token is never shown back.
class ConnectionCard extends StatefulWidget {
  const ConnectionCard({super.key});

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest(ConnectionService connection) async {
    final token = _controller.text;
    if (token.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final saved = await connection.saveAndTest(token);
    if (saved && mounted) _controller.clear();
  }

  String _statusText(ConnectionService connection) {
    return switch (connection.status) {
      ConnectionStatus.unknown =>
        connection.hasToken ? Labels.tokenSaved : Labels.noTokenSaved,
      ConnectionStatus.checking => Labels.connectionChecking,
      ConnectionStatus.connected => Labels.connectionOk,
      ConnectionStatus.badToken => Labels.connectionBadToken,
      ConnectionStatus.unreachable => Labels.connectionUnreachable,
      ConnectionStatus.unexpected => Labels.connectionUnexpected,
    };
  }

  Color _statusColor(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => AppColors.accent,
      ConnectionStatus.badToken ||
      ConnectionStatus.unexpected =>
        AppColors.danger,
      _ => AppColors.textSecondary,
    };
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.button),
        borderSide: BorderSide(color: color),
      );

  Widget _button(String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.button),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        label,
        style: AppType.bodyMuted.copyWith(color: AppColors.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    final busy = connection.status == ConnectionStatus.checking;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Labels.connection, style: AppType.sectionLabel),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            enabled: !busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            style: AppType.body,
            cursorColor: AppColors.accent,
            onSubmitted: (_) => _saveAndTest(connection),
            decoration: InputDecoration(
              isDense: true,
              hintText: Labels.tokenHint,
              hintStyle: AppType.bodyMuted,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: _border(AppColors.hairline),
              disabledBorder: _border(AppColors.hairline),
              focusedBorder: _border(AppColors.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _statusText(connection),
            style: AppType.bodyMuted
                .copyWith(color: _statusColor(connection.status)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _button(
                Labels.saveAndTest,
                busy ? null : () => _saveAndTest(connection),
              ),
              if (connection.hasToken) ...[
                _button(
                  Labels.testConnection,
                  busy ? null : connection.check,
                ),
                TextButton(
                  onPressed: busy ? null : connection.forget,
                  child: Text(Labels.forgetToken, style: AppType.bodyMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
