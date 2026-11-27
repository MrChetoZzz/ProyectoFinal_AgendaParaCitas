using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.models
{
    public class Cita
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int PsicologaId { get; set; }

        [Required]
        public int PacienteId { get; set; }

        [Required]
        public DateOnly FechaCita { get; set; }

        [Required]
        public TimeSpan HoraInicio { get; set; }

        [Required]
        public TimeSpan HoraFin { get; set; }

        [Required]
        [MaxLength(20)]
        public string Estado { get; set; } = "Pendiente";

        [MaxLength(300)]
        public string? MotivoConsulta { get; set; }

        public string? NotasPsicologa { get; set; }

        public DateTime CreadoEn { get; set; }

        public DateTime ActualizadoEn { get; set; }

        // Navegación
        [ForeignKey(nameof(PsicologaId))]
        public Psicologa Psicologa { get; set; } = null!;

        [ForeignKey(nameof(PacienteId))]
        public Paciente Paciente { get; set; } = null!;
    }
}