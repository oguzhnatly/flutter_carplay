package com.oguzhnatly.flutter_android_auto

enum class FAAConnectionTypes {
    connected,
    background,
    disconnected,
}

enum class FAAChannelTypes {
    onAndroidAutoConnectionChange,
    setRootTemplate,
    forceUpdateRootTemplate,
    pushTemplate,
    popTemplate,
    popToRootTemplate,
    updateListTemplateSections,
    updatePaneTemplate,
    onListItemSelected,
    onListItemSelectedComplete,
    onListSectionSelected,
    onToggleCheckedChange,
    onPaneActionPressed,
    onScreenBackButtonPressed,
    setAlert,
    closePresent,
    onAlertActionPressed,
    onPresentStateChanged,
    updateTabBarTemplates,
    onTabBarItemSelected,
    onGridButtonPressed,
    onGridButtonSelectedComplete,
    updateMessageTemplate,
    updateLongMessageTemplate,
}
