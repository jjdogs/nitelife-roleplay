using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using CitizenFX.Core;
using CitySimulationEngine.Models;

namespace CitySimulationEngine.Services
{
    public class JobGenerator
    {
        private VehicleSimulator _vehicleSimulator;
        private ConcurrentDictionary<string, TowJob> _activeJobs;
        private Random _random;

        public JobGenerator(VehicleSimulator vehicleSimulator)
        {
            _vehicleSimulator = vehicleSimulator;
            _activeJobs = new ConcurrentDictionary<string, TowJob>();
            _random = new Random();
        }

        public void GenerateBreakdownJobs()
        {
            foreach (var vehicle in _vehicleSimulator.GetFleet())
            {
                if (_random.NextDouble() < vehicle.BreakdownChance() * 0.001)
                {
                    var reason = GetBreakdownReason(vehicle);
                    var job = new TowJob
                    {
                        JobId           = Guid.NewGuid().ToString(),
                        JobType         = "breakdown",
                        VehicleModel    = vehicle.Model,
                        VehiclePlate    = vehicle.Plate,
                        Location        = vehicle.LastKnownPosition,
                        LocationHeading = vehicle.LastKnownHeading,
                        Reason          = reason,
                        DialogText      = GenerateDialogText(vehicle, reason),
                        PayAmount       = CalculatePay(vehicle),
                        OwnerName       = vehicle.OwnerName,
                        CreatedAt       = DateTime.Now,
                        IsReserved      = false
                    };

                    _activeJobs[job.JobId] = job;
                    Debug.WriteLine($"[JobGenerator] Created breakdown job: {job.VehicleModel} at ({job.Location.X}, {job.Location.Y})");
                }
            }
        }

        public TowJob ForceGenerateJob()
        {
            var fleet = _vehicleSimulator.GetFleet().ToList();
            if (fleet.Count == 0) return null;
            var vehicle = fleet[_random.Next(fleet.Count)];
            var reason  = GetBreakdownReason(vehicle);
            var job = new TowJob
            {
                JobId           = Guid.NewGuid().ToString(),
                JobType         = "breakdown",
                VehicleModel    = vehicle.Model,
                VehiclePlate    = vehicle.Plate,
                Location        = vehicle.LastKnownPosition,
                LocationHeading = vehicle.LastKnownHeading,
                Reason          = reason,
                DialogText      = GenerateDialogText(vehicle, reason),
                PayAmount       = CalculatePay(vehicle),
                OwnerName       = vehicle.OwnerName,
                CreatedAt       = DateTime.Now,
                IsReserved      = false
            };
            _activeJobs[job.JobId] = job;
            Debug.WriteLine($"[JobGenerator] Force-generated job: {job.VehicleModel} ({job.VehiclePlate})");
            return job;
        }

        private string GetBreakdownReason(VirtualVehicle vehicle)
        {
            if (vehicle.Condition < 30) return "Engine failure - vehicle won't start";
            if (vehicle.Condition < 50) return "Overheating - steam from hood";
            if (vehicle.Condition < 70) return "Flat tire - driver stranded";
            return "Electrical issue - dashboard lights flickering";
        }

        private string GenerateDialogText(VirtualVehicle vehicle, string reason)
        {
            if (reason.Contains("Engine failure"))
                return $"I don't know what happened — it just died on me. The {vehicle.Model} won't start at all. I've been stuck here for a while now, I really need a tow.";
            if (reason.Contains("Overheating"))
                return $"The hood started steaming so I pulled straight over. It's my {vehicle.Model}, plate {vehicle.Plate}. I think it overheated badly. Please, can you tow it for me?";
            if (reason.Contains("Flat tire"))
                return $"I blew a tire and I've got nowhere to go. It's the {vehicle.Model} right there. I'd really appreciate the help getting it somewhere safe.";
            return $"The whole dashboard lit up and the car started acting weird, so I killed the engine. It's my {vehicle.Model}. I'm not sure what's wrong but I can't drive it like this.";
        }

        private int CalculatePay(VirtualVehicle vehicle)
        {
            int basePay = 150;
            int conditionBonus = (int)((100 - vehicle.Condition) * 2);
            return basePay + conditionBonus;
        }

        public List<TowJob> GetAvailableJobs()
        {
            return _activeJobs.Values.Where(j => !j.IsReserved).ToList();
        }

        public TowJob ReserveJob(string jobId, string playerId)
        {
            if (_activeJobs.TryGetValue(jobId, out var job) && !job.IsReserved)
            {
                job.IsReserved = true;
                job.ReservedBy = playerId;
                return job;
            }
            return null;
        }

        public TowJob CompleteJob(string jobId)
        {
            _activeJobs.TryRemove(jobId, out var job);
            return job;
        }
    }
}
