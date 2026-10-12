using System.Reflection;

namespace FitnessBuddy.BuildingBlocks;

/// <summary>Marker for the BuildingBlocks assembly (used by architecture tests).</summary>
public static class BuildingBlocksAssembly
{
    /// <summary>The BuildingBlocks assembly.</summary>
    public static Assembly Assembly => typeof(BuildingBlocksAssembly).Assembly;
}
