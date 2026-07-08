using Velopack;
using Velopack.Sources;

// Must be the very first thing in Main - handles Velopack's install/uninstall/update
// lifecycle hooks when this exe is invoked with special args during those operations.
VelopackApp.Build().Run();

var version = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version;
Console.WriteLine($"FluxBooks Spike App - running version {version} - UPDATED BUILD MARKER");
Console.WriteLine($"Executable location: {System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName}");

if (args.Length > 0 && args[0] == "check-update")
{
    await CheckForUpdate();
}
else
{
    Console.WriteLine("Run with 'check-update' argument to check for and apply an update.");
    Console.WriteLine("Press Enter to exit.");
    Console.ReadLine();
}

static async Task CheckForUpdate()
{
    var source = new GithubSource("https://github.com/adolphlo/fluxbooks-spike", null, false);
    var mgr = new UpdateManager(source);

    Console.WriteLine("Checking for updates...");
    var newVersion = await mgr.CheckForUpdatesAsync();
    if (newVersion == null)
    {
        Console.WriteLine("No update available - already up to date.");
        return;
    }

    Console.WriteLine($"Update available: {newVersion.TargetFullRelease.Version}. Downloading...");
    await mgr.DownloadUpdatesAsync(newVersion);
    Console.WriteLine("Downloaded. Applying and restarting...");
    mgr.ApplyUpdatesAndRestart(newVersion);
}
