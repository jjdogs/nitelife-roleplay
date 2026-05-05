using System;
using CitizenFX.Core;

namespace CitySimulationEngine.Models
{
    public class VirtualVehicle
    {
        public int Id { get; set; }
        public string Model { get; set; }
        public string Plate { get; set; }
        public float Condition { get; set; } // 0-100
        public int Age { get; set; }
        public Vector3 LastKnownPosition { get; set; }
        public float LastKnownHeading { get; set; }
        public DateTime LastMaintenance { get; set; }
        public string OwnerName { get; set; }

        public float BreakdownChance()
        {
            float baseChance = (100 - Condition) / 100f;
            float ageMultiplier = 1 + (Age * 0.1f);
            return baseChance * ageMultiplier;
        }
    }
}
