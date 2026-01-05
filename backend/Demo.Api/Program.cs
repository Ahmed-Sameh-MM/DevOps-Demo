using Microsoft.EntityFrameworkCore;
using Demo.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});

var connStr = builder.Configuration.GetConnectionString("Default")
             ?? throw new Exception("Missing connection string: ConnectionStrings:Default");

builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(connStr));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");

app.MapGet("/health", () => Results.Ok("Server is Healthy and Operational!"));

app.MapGet("/locations", async (AppDbContext db) =>
{
    var locations = await db.Locations
        .OrderBy(x => x.Id)
        .Select(x => new { x.Id, x.Name, x.Lat, x.Lng })
        .ToListAsync();

    return Results.Ok(locations);
});

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();

    if (!db.Locations.Any())
    {
        db.Locations.AddRange(
            new Demo.Api.Models.Location { Name = "Horsham", Lat = 51.063, Lng = -0.325 },
            new Demo.Api.Models.Location { Name = "Brighton", Lat = 52.001, Lng = 0.750 },
            new Demo.Api.Models.Location { Name = "London", Lat = 51.507, Lng = -0.127 }
        );
        
        db.SaveChanges();
    }
}

// app.UseHttpsRedirection();

// app.UseAuthorization();

// app.MapControllers();

app.Run("http://0.0.0.0:8080");
