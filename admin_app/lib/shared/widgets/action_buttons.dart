import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Standardized action buttons widget
class ActionButtonsWidget extends StatelessWidget {
  final List<ActionButton> actions;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final bool compact;

  const ActionButtonsWidget({
    super.key,
    required this.actions,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing = 8.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = actions.map((action) => _buildActionButton(action, context)).toList();

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _addSpacing(children),
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _addSpacing(children),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> children) {
    if (children.isEmpty) return children;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        if (direction == Axis.horizontal) {
          spacedChildren.add(SizedBox(width: spacing));
        } else {
          spacedChildren.add(SizedBox(height: spacing));
        }
      }
    }
    return spacedChildren;
  }

  Widget _buildActionButton(ActionButton action, BuildContext context) {
    final buttonStyle = _getButtonStyle(action.type);

    if (action.iconOnly && compact) {
      return IconButton(
        onPressed: action.enabled ? action.onPressed : null,
        icon: Icon(action.icon, color: buttonStyle.iconColor),
        tooltip: action.tooltip ?? action.label,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      );
    }

    return ElevatedButton.icon(
      onPressed: action.enabled ? action.onPressed : null,
      icon: Icon(action.icon, size: compact ? 16 : 18),
      label: action.iconOnly
          ? const SizedBox.shrink()
          : Text(
              action.label,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.enabled ? buttonStyle.backgroundColor : AppColors.disabled,
        foregroundColor: action.enabled ? buttonStyle.foregroundColor : AppColors.textDisabled,
        elevation: action.type == ActionType.primary ? 2 : 0,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: action.type == ActionType.outline
            ? BorderSide(color: buttonStyle.borderColor ?? AppColors.border)
            : null,
      ),
    );
  }

  ActionButtonStyle _getButtonStyle(ActionType type) {
    switch (type) {
      case ActionType.primary:
        return ActionButtonStyle(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
        );
      case ActionType.secondary:
        return ActionButtonStyle(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
        );
      case ActionType.success:
        return ActionButtonStyle(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
        );
      case ActionType.danger:
        return ActionButtonStyle(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
        );
      case ActionType.warning:
        return ActionButtonStyle(
          backgroundColor: AppColors.warning,
          foregroundColor: AppColors.textPrimary,
          iconColor: AppColors.textPrimary,
        );
      case ActionType.info:
        return ActionButtonStyle(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
        );
      case ActionType.outline:
        return ActionButtonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          iconColor: AppColors.primary,
          borderColor: AppColors.primary,
        );
      case ActionType.ghost:
        return ActionButtonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textSecondary,
          iconColor: AppColors.textSecondary,
        );
    }
  }
}

/// Pre-configured action buttons for common operations
class ActionButtons {
  static ActionButton edit({
    required VoidCallback onPressed,
    String label = 'Edit',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.edit,
      type: ActionType.primary,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Edit item',
    );
  }

  static ActionButton delete({
    required VoidCallback onPressed,
    String label = 'Delete',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.delete,
      type: ActionType.danger,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Delete item',
    );
  }

  static ActionButton view({
    required VoidCallback onPressed,
    String label = 'View',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.visibility,
      type: ActionType.info,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'View details',
    );
  }

  static ActionButton add({
    required VoidCallback onPressed,
    String label = 'Add',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.add,
      type: ActionType.success,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Add new item',
    );
  }

  static ActionButton save({
    required VoidCallback onPressed,
    String label = 'Save',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.save,
      type: ActionType.primary,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Save changes',
    );
  }

  static ActionButton cancel({
    required VoidCallback onPressed,
    String label = 'Cancel',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.cancel,
      type: ActionType.outline,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Cancel operation',
    );
  }

  static ActionButton export({
    required VoidCallback onPressed,
    String label = 'Export',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.download,
      type: ActionType.secondary,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Export data',
    );
  }

  static ActionButton import({
    required VoidCallback onPressed,
    String label = 'Import',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.upload,
      type: ActionType.secondary,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Import data',
    );
  }

  static ActionButton refresh({
    required VoidCallback onPressed,
    String label = 'Refresh',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.refresh,
      type: ActionType.ghost,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Refresh data',
    );
  }

  static ActionButton duplicate({
    required VoidCallback onPressed,
    String label = 'Duplicate',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.content_copy,
      type: ActionType.secondary,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Duplicate item',
    );
  }

  static ActionButton archive({
    required VoidCallback onPressed,
    String label = 'Archive',
    bool enabled = true,
    bool iconOnly = false,
  }) {
    return ActionButton(
      label: label,
      icon: Icons.archive,
      type: ActionType.warning,
      onPressed: onPressed,
      enabled: enabled,
      iconOnly: iconOnly,
      tooltip: 'Archive item',
    );
  }
}

/// Action button configuration
class ActionButton {
  final String label;
  final IconData icon;
  final ActionType type;
  final VoidCallback onPressed;
  final bool enabled;
  final bool iconOnly;
  final String? tooltip;

  const ActionButton({
    required this.label,
    required this.icon,
    required this.type,
    required this.onPressed,
    this.enabled = true,
    this.iconOnly = false,
    this.tooltip,
  });
}

/// Action button types
enum ActionType {
  primary,
  secondary,
  success,
  danger,
  warning,
  info,
  outline,
  ghost,
}

/// Action button style configuration
class ActionButtonStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final Color? borderColor;

  const ActionButtonStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    this.borderColor,
  });
}