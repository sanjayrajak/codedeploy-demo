var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

// Health check — called by CodeDeploy validate_health.sh hook.
// Returns 200 OK when the service is ready; CodeDeploy rolls back if it doesn't.
app.MapGet("/health", () => Results.Ok(new
{
    status  = "healthy",
    version = typeof(Program).Assembly.GetName().Version?.ToString() ?? "unknown",
    utc     = DateTime.UtcNow
})).WithName("GetHealth");

// Simple hello endpoints
app.MapGet("/hello", () => new { message = "Hello, World!" })
    .WithName("GetHello");

app.MapGet("/hello/{name}", (string name) => new { message = $"Hello, {name}!" })
    .WithName("GetHelloByName");

app.Run();
