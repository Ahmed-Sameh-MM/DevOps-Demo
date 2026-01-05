using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Demo.Api.Data;

public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        // Load config at design-time (dotnet ef)
        var config = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables() // enables ConnectionStrings__Default
            .Build();

        var connStr = config.GetConnectionString("Default");

        if (string.IsNullOrWhiteSpace(connStr))
        {
            throw new InvalidOperationException(
                "Missing connection string. Set ConnectionStrings__Default as an environment variable " +
                "or provide ConnectionStrings:Default in appsettings.Development.json (and don't commit it)."
            );
        }

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer(connStr)
            .Options;

        return new AppDbContext(options);
    }
}
