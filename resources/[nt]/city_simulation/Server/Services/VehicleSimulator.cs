using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;
using CitizenFX.Core;
using CitySimulationEngine.Models;

namespace CitySimulationEngine.Services
{
    public class VehicleSimulator
    {
        private ConcurrentDictionary<int, VirtualVehicle> _fleet;
        private Random _random;

        public VehicleSimulator()
        {
            _fleet = new ConcurrentDictionary<int, VirtualVehicle>();
            _random = new Random();
            InitializeFleet();
        }

        private static readonly (Vector3 coords, float heading)[] SpawnPoints =
        {
            (new Vector3( 135f, -1069f,  29f), 248f),  // Alta St & Olympic Fwy
            (new Vector3(-698f,  -935f,  19f),  90f),  // Innocence Blvd
            (new Vector3( 916f, -2017f,  31f),  40f),  // Olympic Fwy East
            (new Vector3(-524f,  -210f,  36f), 200f),  // West Eclipse Blvd
            (new Vector3( 254f,  -827f,  30f), 315f),  // Rockford Drive
            (new Vector3(-157f, -1262f,  31f), 270f),  // Pillbox Hill
            (new Vector3( 378f,  -610f,  28f), 180f),  // Rockford Hills
            (new Vector3(-572f,  -713f,  33f),   0f),  // Vespucci Blvd
        };

        private void InitializeFleet()
        {
            string[] models = { "buffalo", "emperor", "futo", "blista", "asea", "ingot", "prairie", "sultan" };

            for (int i = 0; i < 50; i++)
            {
                var spawn = SpawnPoints[_random.Next(SpawnPoints.Length)];
                _fleet[i] = new VirtualVehicle
                {
                    Id = i,
                    Model = models[_random.Next(models.Length)],
                    Plate = GeneratePlate(),
                    Condition = _random.Next(30, 100),
                    Age = _random.Next(1, 15),
                    LastKnownPosition = spawn.coords,
                    LastKnownHeading = spawn.heading,
                    LastMaintenance = DateTime.Now.AddDays(-_random.Next(1, 365)),
                    OwnerName = GenerateOwnerName()
                };
            }

            Debug.WriteLine($"[CitySimulation] Initialized fleet with {_fleet.Count} virtual vehicles");
        }

        private string GeneratePlate()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            char[] plate = new char[8];
            for (int i = 0; i < 8; i++)
                plate[i] = chars[_random.Next(chars.Length)];
            return new string(plate);
        }


        private string GenerateOwnerName()
        {
            string[] first = { "John", "Sarah", "Mike", "Emily", "David", "Lisa" };
            string[] last  = { "Smith", "Johnson", "Williams", "Brown", "Davis", "Martinez" };
            return $"{first[_random.Next(first.Length)]} {last[_random.Next(last.Length)]}";
        }

        public IEnumerable<VirtualVehicle> GetFleet() => _fleet.Values;

        public void SetSpawnPoints(List<(Vector3 coords, float heading)> spots)
        {
            foreach (var vehicle in _fleet.Values)
            {
                var spot = spots[_random.Next(spots.Count)];
                vehicle.LastKnownPosition = spot.coords;
                vehicle.LastKnownHeading  = spot.heading;
            }
            Debug.WriteLine($"[CitySimulation] Reassigned fleet to {spots.Count} spawn points from nt_tow");
        }

        public async Task SimulateFleetAsync()
        {
            while (true)
            {
                await Task.Run(() =>
                {
                    foreach (var vehicle in _fleet.Values)
                        vehicle.Condition = Math.Max(0, vehicle.Condition - 0.01f);
                });

                await Task.Delay(60000);
            }
        }
    }
}
