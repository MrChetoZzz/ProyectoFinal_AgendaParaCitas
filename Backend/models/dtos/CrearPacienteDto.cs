namespace Backend.models.dtos
{
    public class CreatePacienteDto
    {
        public string NombreCompleto { get; set; } = string.Empty;

        public string Telefono { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;
    }
}