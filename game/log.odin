#+build !js
package karl2d_game

import "core:log"

error :: log.error
errorf :: log.errorf
warn :: log.warn
warnf :: log.warnf
trace :: log.info
tracef :: log.infof
debug :: log.debug
debugf :: log.debugf

init_logger :: proc() -> log.Logger {
	return log.create_console_logger(lowest = .Debug, opt = {.Procedure, .Line})
}

delete_logger :: proc(logger: log.Logger) {
	log.destroy_console_logger(logger)
}
