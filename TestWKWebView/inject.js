const oldConsoleLog = console.log;
console.log = function(...args) {
  oldConsoleLog.apply(console, args);
  window.webkit.messageHandlers.demo.postMessage(args);
}
