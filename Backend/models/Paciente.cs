using System.ComponentModel.DataAnnotations;

namespace Backend.models
{
    public class Paciente
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(120)]
        public string NombreCompleto { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string Telefono { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        public string Email { get; set; } = string.Empty;

        public DateTime CreadoEn { get; set; }

        // Navegación
        public ICollection<Cita> Citas { get; set; } = new List<Cita>();
    }
}