using System;
using CitizenFX.Core;

namespace CitySimulationEngine.Models
{
    public class TowJob
    {
        public string JobId { get; set; }
        public string JobType { get; set; }
        public string VehicleModel { get; set; }
        public string VehiclePlate { get; set; }
        public Vector3 Location { get; set; }
        public float LocationHeading { get; set; }
        public string Reason { get; set; }
        public string DialogText { get; set; }
        public int PayAmount { get; set; }
        public string OwnerName { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsReserved { get; set; }
        public string ReservedBy { get; set; }
    }
}
