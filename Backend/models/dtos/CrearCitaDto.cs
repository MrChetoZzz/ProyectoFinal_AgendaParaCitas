namespace Backend.models.dtos
{
    public class CrearCitaDto
    {
        public string Nombre { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public int Edad { get; set; }
        public string Categoria { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
        public TimeSpan Hora { get; set; }
    }
}