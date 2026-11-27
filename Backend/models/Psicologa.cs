using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.models
{
    public class Psicologa
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(120)]
        public string NombreCompleto { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Especialidad { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        public string CedulaProfesional { get; set; } = string.Empty;

        public string? Biografia { get; set; }

        [Required]
        [MaxLength(20)]
        public string TelefonoContacto { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string DireccionConsultorio { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? FotoUrl { get; set; }

        [Required]
        public int DuracionSesionMin { get; set; } = 50;

        [Required]
        [MaxLength(150)]
        public string EmailLogin { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string PasswordHash { get; set; } = string.Empty;

        public DateTime CreadoEn { get; set; }

        // Navegación
        public ICollection<HorarioBase> HorariosBase { get; set; } = new List<HorarioBase>();
        public ICollection<BloqueoAgenda> BloqueosAgenda { get; set; } = new List<BloqueoAgenda>();
        public ICollection<Cita> Citas { get; set; } = new List<Cita>();
    }
}