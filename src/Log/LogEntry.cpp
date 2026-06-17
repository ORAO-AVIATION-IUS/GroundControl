#include "LogEntry.h"

namespace agc {

const char* levelName(LogLevel l) {
	switch (l) {
		case LogLevel::Debug:    return "Debug";
		case LogLevel::Info:     return "Info";
		case LogLevel::Warning:  return "Warning";
		case LogLevel::Error:    return "Error";
		case LogLevel::Critical: return "Critical";
	}
	return "Info";
}

} // namespace agc
