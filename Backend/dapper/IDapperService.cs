using Dapper;

namespace Backend.dapper
{
    public interface IDapperService
    {
        Task<DapperResponse> ExecuteQueryAsync<T>(string query, StoredProcedureInf parameters, string connectionId, bool hasArray = false);
        Task<DapperResponse> ExecuteStoredProcedureAsync<T>(StoredProcedureInf qData, DynamicParameters? parameters = null, bool hasArray = false);
        Task<DapperResponse> ExecuteFunctionAsync<T>(string sql, DynamicParameters? parameters = null, string connectionId = "DefaultConnection", bool hasArray = false);
        Task<DapperResponse> ExecuteProcedureAsync<T>(string procedure, DynamicParameters? parameters = null, string connectionId = "DefaultConnection");
    }
}