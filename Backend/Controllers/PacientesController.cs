using Backend.models.dtos;
using Backend.services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PacientesController : ControllerBase
    {
        private readonly IPacientesService _service;

        public PacientesController(
            IPacientesService service)
        {
            _service = service;
        }

        [HttpGet("/Pacientes")]
        public async Task<IActionResult> GetAll(
            [FromQuery] string? busqueda)
        {
            var result =
                await _service.GetAll(busqueda);

            return Ok(result);
        }

        [HttpGet("/PacientePorId")]
        public async Task<IActionResult> GetById(
            int id)
        {
            var result =
                await _service.GetById(id);

            if (result == null)
            {
                return NotFound();
            }

            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> Create(
            [FromBody] CreatePacienteDto dto)
        {
            var result =
                await _service.Create(dto);

            return Ok(new { success = result });
        }

        [HttpPost("/ObtenerOCrearPaciente")]
        public async Task<IActionResult> ObtenerOCrear(
            [FromBody] CreatePacienteDto dto)
        {
            var result =
                await _service.ObtenerOCrear(dto);

            return Ok(new { success = result });
        }

        [HttpPut("/ActualizarPacientes")]
        public async Task<IActionResult> Update(
            [FromBody] UpdatePacienteDto dto)
        {
            var result =
                await _service.Update(dto);

            return Ok(new { success = result });
        }

        [HttpDelete("/DeleteCustomer")]
        public async Task<IActionResult> Delete(
            int id)
        {
            var result =
                await _service.Delete(id);

            return Ok(new { success = result });
        }
    }
}