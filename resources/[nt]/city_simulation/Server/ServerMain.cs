using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CitizenFX.Core;
using CitizenFX.Core.Native;
using CitySimulationEngine.Services;
using Newtonsoft.Json;

namespace CitySimulationEngine
{
    public class CitySimulation : BaseScript
    {
        private VehicleSimulator _vehicleSimulator;
        private JobGenerator _jobGenerator;

        public CitySimulation()
        {
            Debug.WriteLine("[CitySimulation] Constructor called");
            Debug.WriteLine("[CitySimulation] Starting City Simulation Engine...");

            _vehicleSimulator = new VehicleSimulator();
            _jobGenerator = new JobGenerator(_vehicleSimulator);

            Task.Run(() => _vehicleSimulator.SimulateFleetAsync());

            Tick += OnTick;

            EventHandlers["citysim:requestJobs"] += new Action<Player>(OnRequestJobs);
            EventHandlers["citysim:acceptJob"]   += new Action<Player, string>(OnAcceptJob);
            EventHandlers["citysim:completeJob"] += new Action<Player, string>(OnCompleteJob);
            EventHandlers["citysim:giveJob"]          += new Action<Player>(OnGiveJob);
            EventHandlers["citysim:loadSpawnPoints"] += new Action<string>(OnLoadSpawnPoints);
            EventHandlers["citysim:addJob"]          += new Action<Player, int>(OnAddJob);
            EventHandlers["onServerResourceStart"]   += new Action<string>(OnResourceStart);

            API.RegisterCommand("citytest", new Action<int, List<object>, string>((source, args, raw) =>
            {
                Debug.WriteLine("[CitySimulation] citytest command fired");
            }), false);

            Debug.WriteLine("[CitySimulation] Engine started successfully!");
        }

        private void OnGiveJob([FromSource] Player player)
        {
            try
            {
                var jobs = _jobGenerator.GetAvailableJobs();
                if (jobs.Count == 0)
                    _jobGenerator.ForceGenerateJob();

                jobs = _jobGenerator.GetAvailableJobs();
                if (jobs.Count == 0)
                {
                    player.TriggerEvent("citysim:jobUnavailable");
                    return;
                }

                var job = _jobGenerator.ReserveJob(jobs[0].JobId, player.Handle);
                if (job != null)
                {
                    string json = JsonConvert.SerializeObject(job);
                    player.TriggerEvent("citysim:jobAccepted", json);
                    Debug.WriteLine($"[CitySimulation] Force-assigned job to {player.Name}: {job.VehicleModel} ({job.VehiclePlate})");
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[CitySimulation] OnGiveJob error: {ex.Message}");
            }
        }

        private void OnLoadSpawnPoints(string spotsJson)
        {
            try
            {
                var data = JsonConvert.DeserializeObject<List<SpawnPointDto>>(spotsJson);
                var spots = data.Select(s => (new Vector3(s.X, s.Y, s.Z), s.Heading)).ToList();
                _vehicleSimulator.SetSpawnPoints(spots);
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[CitySimulation] OnLoadSpawnPoints error: {ex.Message}");
            }
        }

        private class SpawnPointDto
        {
            public float X { get; set; }
            public float Y { get; set; }
            public float Z { get; set; }
            public float Heading { get; set; }
        }

        private void OnAddJob([FromSource] Player player, int count)
        {
            count = Math.Min(Math.Max(count, 1), 10);
            for (int i = 0; i < count; i++)
                _jobGenerator.ForceGenerateJob();
            Debug.WriteLine($"[CitySimulation] {player.Name} queued {count} job(s). Available: {_jobGenerator.GetAvailableJobs().Count}");
        }

        private void OnResourceStart(string resourceName)
        {
            if (resourceName != API.GetCurrentResourceName()) return;
            Debug.WriteLine("[CitySimulation] onServerResourceStart fired");
        }

        private async Task OnTick()
        {
            await Delay(30000);
            _jobGenerator.GenerateBreakdownJobs();
        }

        private void OnRequestJobs([FromSource] Player player)
        {
            try
            {
                var jobs = _jobGenerator.GetAvailableJobs();
                string json = JsonConvert.SerializeObject(jobs);
                player.TriggerEvent("citysim:receiveJobs", json);
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[CitySimulation] OnRequestJobs error: {ex.Message}");
            }
        }

        private void OnAcceptJob([FromSource] Player player, string jobId)
        {
            try
            {
                var job = _jobGenerator.ReserveJob(jobId, player.Handle);
                if (job != null)
                {
                    string json = JsonConvert.SerializeObject(job);
                    player.TriggerEvent("citysim:jobAccepted", json);
                    Debug.WriteLine($"[CitySimulation] Player {player.Name} accepted job {jobId}");
                }
                else
                {
                    player.TriggerEvent("citysim:jobUnavailable");
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[CitySimulation] OnAcceptJob error: {ex.Message}");
            }
        }

        private void OnCompleteJob([FromSource] Player player, string jobId)
        {
            try
            {
                var job = _jobGenerator.CompleteJob(jobId);
                if (job == null) return;
                TriggerEvent("citysim:jobReward", int.Parse(player.Handle), job.PayAmount);
                player.TriggerEvent("citysim:jobPaid", job.PayAmount);
                Debug.WriteLine($"[CitySimulation] {player.Name} completed job {jobId} — paid ${job.PayAmount}");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[CitySimulation] OnCompleteJob error: {ex.Message}");
            }
        }
    }
}
