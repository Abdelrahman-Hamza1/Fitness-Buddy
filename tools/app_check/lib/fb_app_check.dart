/// Architecture checks for the Flutter app: import boundaries, raw
/// user-facing strings, left/right layout. See `tools/app_check/README.md`.
library;

export 'src/checker.dart'
    show
        allowCount,
        allowableRules,
        checkFile,
        connectionLibraries,
        driftWriteCalls,
        ioPackages,
        isGenerated,
        isIoPackage,
        opensConnection,
        textArguments;
export 'src/cli.dart';
export 'src/rules.dart';
export 'src/source_scanner.dart';
