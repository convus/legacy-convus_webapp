// If a user presses spacebar while having selected a button, treat that as a click
const KeyboardOrClick = (event) => {
  if (event.type === 'click') {
    return true
  } else if (event.type === 'keypress') {
    const code = event.charCode || event.keyCode
    if (code === 32 || code === 13) {
      return true
    }
  } else {
    return false
  }
}
export default KeyboardOrClick
