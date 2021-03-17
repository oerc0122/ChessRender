extends Node


func error(title: String, message: String):
    $ErrorPopup.window_title = title
    $ErrorPopup/ErrorMessage.text = message
    $ErrorPopup.popup_centered()
