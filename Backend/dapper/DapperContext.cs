using System.Data;
using Npgsql;

namespace Backend.dapper
{
    public class DapperContext
    {
        private readonly IConfiguration _configuration;

        public DapperContext(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public IDbConnection CreateConnection(string connectionName)
        {
            return new NpgsqlConnection(
                _configuration.GetConnectionString(connectionName));
        }
    }
}