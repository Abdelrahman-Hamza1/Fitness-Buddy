namespace FitnessBuddy.Modules.UserData.Application;

internal interface ISyncTelemetry
{
    void Record(string operation, int changes, int stale, int invalid, double milliseconds);
}
