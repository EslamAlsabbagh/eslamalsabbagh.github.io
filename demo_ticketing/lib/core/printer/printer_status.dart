/// What a screen last learnt about the counter's printer. The sell screen's
/// badge only uses the first four; the open shift screen also test-prints.
enum PrinterStatus { notSet, checking, reachable, unreachable, printing, printed, printFailed }
