using Backend.dapper;
using Backend.models;
using Backend.models.dtos;
using Dapper;

namespace Backend.Repository
{
    public class PacientesRepository : IPacientesRepository
    {
        private readonly IDapperService _dapperService;

        private const string ConnectionId = "DefaultConnection";

        public PacientesRepository(IDapperService dapperService)
        {
            _dapperService = dapperService;
        }

        public async Task<DapperResponse> GetAll(string? busqueda)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_busqueda", busqueda);

            return await _dapperService.ExecuteFunctionAsync<Paciente>(
                "SELECT * FROM public.usp_pacientes_get_all()",
                parametros,
                ConnectionId,
                true);
        }

        public async Task<DapperResponse> GetById(int id)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_id", id);

            return await _dapperService.ExecuteFunctionAsync<Paciente>(
                "SELECT * FROM public.usp_pacientes_get_by_id(@p_id)",
                parametros,
                ConnectionId,
                false);
        }

        public async Task<DapperResponse> Create(CreatePacienteDto dto)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_nombre_completo", dto.NombreCompleto);
            parametros.Add("p_telefono", dto.Telefono);
            parametros.Add("p_email", dto.Email);

            return await _dapperService.ExecuteProcedureAsync<Paciente>(
                "public.usp_pacientes_create",
                parametros,
                ConnectionId);
        }

        public async Task<DapperResponse> ObtenerOCrear(
            CreatePacienteDto dto)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_nombre_completo", dto.NombreCompleto);
            parametros.Add("p_telefono", dto.Telefono);
            parametros.Add("p_email", dto.Email);

            return await _dapperService.ExecuteProcedureAsync<Paciente>(
                "public.usp_pacientes_obtener_o_crear",
                parametros,
                ConnectionId);
        }

        public async Task<DapperResponse> Update(
            UpdatePacienteDto dto)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_id", dto.Id);
            parametros.Add("p_nombre_completo", dto.NombreCompleto);
            parametros.Add("p_telefono", dto.Telefono);
            parametros.Add("p_email", dto.Email);

            return await _dapperService.ExecuteProcedureAsync<Paciente>(
                "public.usp_pacientes_update",
                parametros,
                ConnectionId);
        }

        public async Task<DapperResponse> Delete(int id)
        {
            var parametros = new DynamicParameters();

            parametros.Add("p_id", id);

            return await _dapperService.ExecuteProcedureAsync<Paciente>(
                "public.usp_pacientes_delete",
                parametros,
                ConnectionId);
        }
    }
}