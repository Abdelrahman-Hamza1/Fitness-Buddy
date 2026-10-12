// Composition root. Endpoints and modules are added from S03 on.
// The generated Program class is public in .NET 10 (ASP0027), so tests can use typeof(Program).
var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

await app.RunAsync();
