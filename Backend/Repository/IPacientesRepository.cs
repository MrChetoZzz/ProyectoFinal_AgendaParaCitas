using Backend.dapper;
using Backend.models.dtos;

namespace Backend.Repository
{
    public interface IPacientesRepository
    {
        Task<DapperResponse> GetAll(string? busqueda);

        Task<DapperResponse> GetById(int id);

        Task<DapperResponse> Create(CreatePacienteDto dto);

        Task<DapperResponse> ObtenerOCrear(CreatePacienteDto dto);

        Task<DapperResponse> Update(UpdatePacienteDto dto);

        Task<DapperResponse> Delete(int id);
    }
}