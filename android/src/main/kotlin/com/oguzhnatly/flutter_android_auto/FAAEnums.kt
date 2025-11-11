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
    onListItemSelected,
    onListItemSelectedComplete,
    onScreenBackButtonPressed,
}
