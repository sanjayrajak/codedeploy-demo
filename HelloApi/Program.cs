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

// Simple hello endpoints
app.MapGet("/hello", () => new { message = "Hello, World!" })
    .WithName("GetHello");

app.MapGet("/hello/{name}", (string name) => new { message = $"Hello, {name}!" })
    .WithName("GetHelloByName");

app.Run();
