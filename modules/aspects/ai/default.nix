{ den, ... }: {
  den.aspects.ai = {
    includes = [
      den.aspects.pi-coding-agent
      den.aspects.skills
      den.aspects.claude-code
    ];
  };
}
