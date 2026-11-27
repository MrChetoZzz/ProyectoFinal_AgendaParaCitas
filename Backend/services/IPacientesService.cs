using Backend.models;
using Backend.models.dtos;

namespace Backend.services
{
    public interface IPacientesService
    {
        Task<IReadOnlyList<Paciente>> GetAll(
            string? busqueda);

        Task<Paciente?> GetById(int id);

        Task<bool> Create(
            CreatePacienteDto dto);

        Task<bool> ObtenerOCrear(
            CreatePacienteDto dto);

        Task<bool> Update(
            UpdatePacienteDto dto);

        Task<bool> Delete(int id);
    }
}