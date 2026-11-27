using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.models
{
    public class HorarioBase
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int PsicologaId { get; set; }

        [Required]
        public short DiaSemana { get; set; }

        [Required]
        public TimeSpan HoraInicio { get; set; }

        [Required]
        public TimeSpan HoraFin { get; set; }

        public bool Activo { get; set; } = true;

        // Navegación
        [ForeignKey(nameof(PsicologaId))]
        public Psicologa Psicologa { get; set; } = null!;
    }
}