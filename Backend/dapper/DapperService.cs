using System.Data;
using Dapper;

namespace Backend.dapper
{
    public class DapperService : IDapperService
    {
        private readonly DapperContext _dapperContext;

        public DapperService(DapperContext dapperContext)
        {
            _dapperContext = dapperContext;
        }

        public async Task<DapperResponse> ExecuteQueryAsync<T>(
            string query,
            StoredProcedureInf parameters,
            string connectionId,
            bool hasArray = false)
        {
            try
            {
                dynamic? response;

                using IDbConnection connection =
                    _dapperContext.CreateConnection(connectionId);

                if (hasArray)
                {
                    response = await connection.QueryAsync<T>(query);
                }
                else
                {
                    response = await connection.QuerySingleOrDefaultAsync<T>(query);
                }

                return new DapperResponse
                {
                    Success = true,
                    Result = response
                };
            }
            catch (Exception ex)
            {
                return new DapperResponse
                {
                    Success = false,
                    InnerException = ex.Message
                };
            }
        }

        public async Task<DapperResponse> ExecuteStoredProcedureAsync<T>(
            StoredProcedureInf qData,
            DynamicParameters? parameters = null,
            bool hasArray = false)
        {
            try
            {
                dynamic? response;

                using IDbConnection connection =
                    _dapperContext.CreateConnection(qData.IdConnectionString);

                string sql = $"CALL {qData.SchemaName}.{qData.Name}";

                if (hasArray)
                {
                    response = await connection.QueryAsync<T>(
                        sql,
                        parameters,
                        commandType: CommandType.Text);
                }
                else
                {
                    response = await connection.QuerySingleOrDefaultAsync<T>(
                        sql,
                        parameters,
                        commandType: CommandType.Text);
                }

                return new DapperResponse
                {
                    Success = true,
                    Result = response
                };
            }
            catch (Exception ex)
            {
                return new DapperResponse
                {
                    Success = false,
                    InnerException = ex.Message
                };
            }
        }

        public async Task<DapperResponse> ExecuteFunctionAsync<T>(
            string sql,
            DynamicParameters? parameters = null,
            string connectionId = "DefaultConnection",
            bool hasArray = false)
        {
            try
            {
                using IDbConnection connection =
                    _dapperContext.CreateConnection(connectionId);

                object? result;

                if (hasArray)
                {
                    result = await connection.QueryAsync<T>(
                        sql,
                        parameters);
                }
                else
                {
                    result = await connection.QuerySingleOrDefaultAsync<T>(
                        sql,
                        parameters);
                }

                return new DapperResponse
                {
                    Success = true,
                    Result = result
                };
            }
            catch (Exception ex)
            {
                return new DapperResponse
                {
                    Success = false,
                    InnerException = ex.Message
                };
            }
        }

        public async Task<DapperResponse> ExecuteProcedureAsync<T>(
            string procedure,
            DynamicParameters? parameters = null,
            string connectionId = "DefaultConnection")
        {
            try
            {
                using IDbConnection connection =
                    _dapperContext.CreateConnection(connectionId);

                await connection.ExecuteAsync(
                    $"CALL {procedure}",
                    parameters);

                return new DapperResponse
                {
                    Success = true
                };
            }
            catch (Exception ex)
            {
                return new DapperResponse
                {
                    Success = false,
                    InnerException = ex.Message
                };
            }
        }
    }
}