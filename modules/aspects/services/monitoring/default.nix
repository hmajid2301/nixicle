{ den, ... }:
{
  den.aspects.monitoring = {
    includes = [
      den.aspects.monitoringPrometheus
      den.aspects.monitoringGrafana
      den.aspects.monitoringLoki
      den.aspects.monitoringTempo
    ];
  };
}
