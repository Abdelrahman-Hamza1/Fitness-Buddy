namespace FitnessBuddy.BuildingBlocks.Web.Idempotency;

// Bound both request and response buffering before committing any database effect.
internal sealed class LimitedMemoryStream(int maximumBytes) : MemoryStream
{
    private void Check(int count)
    {
        if (Position + count > maximumBytes) { throw new InvalidOperationException("Idempotency response exceeds its buffer limit."); }
    }
    public override void Write(byte[] buffer, int offset, int count) { Check(count); base.Write(buffer, offset, count); }
    public override void Write(ReadOnlySpan<byte> buffer) { Check(buffer.Length); base.Write(buffer); }
    public override Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
    {
        Check(count); return base.WriteAsync(buffer, offset, count, cancellationToken);
    }
    public override ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
    {
        Check(buffer.Length); return base.WriteAsync(buffer, cancellationToken);
    }
    public override void WriteByte(byte value) { Check(1); base.WriteByte(value); }
    public override void SetLength(long value)
    {
        if (value > maximumBytes) { throw new InvalidOperationException("Idempotency response exceeds its buffer limit."); }
        base.SetLength(value);
    }
}
