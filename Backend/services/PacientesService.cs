using Backend.dapper;
using Backend.models;
using Backend.models.dtos;
using Backend.Repository;

namespace Backend.services
{
    public class PacientesService : IPacientesService
    {
        private readonly IPacientesRepository _repository;

        public PacientesService(
            IPacientesRepository repository)
        {
            _repository = repository;
        }

        public async Task<IReadOnlyList<Paciente>> GetAll(
            string? busqueda)
        {
            DapperResponse response =
                await _repository.GetAll(busqueda);

            if (!response.Success)
            {
                return Array.Empty<Paciente>();
            }

            return response.Result is IEnumerable<Paciente> pacientes
                ? pacientes.ToList()
                : Array.Empty<Paciente>();
        }

        public async Task<Paciente?> GetById(int id)
        {
            DapperResponse response =
                await _repository.GetById(id);

            if (!response.Success)
            {
                return null;
            }

            return response.Result as Paciente;
        }

        public async Task<bool> Create(
            CreatePacienteDto dto)
        {
            DapperResponse response =
                await _repository.Create(dto);

            return response.Success;
        }

        public async Task<bool> ObtenerOCrear(
            CreatePacienteDto dto)
        {
            DapperResponse response =
                await _repository.ObtenerOCrear(dto);

            return response.Success;
        }

        public async Task<bool> Update(
            UpdatePacienteDto dto)
        {
            DapperResponse response =
                await _repository.Update(dto);

            return response.Success;
        }

        public async Task<bool> Delete(int id)
        {
            DapperResponse response =
                await _repository.Delete(id);

            return response.Success;
        }
    }
}