/// How long a server call waits for an answer before it counts as the server
/// being unreachable (ADR-0039). A dead server can take a request and never
/// answer, which left spinners turning forever.
///
/// 10 s is the default `offline_health_check_seconds`, the wait after which
/// the counter counts as offline (ADR-0025). Supabase stops every
/// `authenticated` statement after 8 s anyway, so this never gives up on a
/// call the server would have finished. A function with a longer
/// `statement_timeout` of its own (`sales_report`, ADR-0032) needs a longer
/// wait.
const serverCallTimeout = Duration(seconds: 10);
