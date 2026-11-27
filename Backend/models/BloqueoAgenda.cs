using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.models
{
    public class BloqueoAgenda
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int PsicologaId { get; set; }

        [Required]
        public DateTime FechaInicio { get; set; }

        [Required]
        public DateTime FechaFin { get; set; }

        [MaxLength(150)]
        public string? Motivo { get; set; }

        // Navegación
        [ForeignKey(nameof(PsicologaId))]
        public Psicologa Psicologa { get; set; } = null!;
    }
}