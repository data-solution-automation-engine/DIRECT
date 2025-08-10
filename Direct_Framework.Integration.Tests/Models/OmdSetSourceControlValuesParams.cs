namespace IntegrationTests.Models;

/// <summary>
/// Model Class for [omd].[SetSourceControlValues] stored procedure parameters.
/// Including matching defaults from the stored procedure.
/// </summary>
public class OmdSetSourceControlValuesParams
{
  // Input parameters
  public long? ModuleInstanceId { get; set; }
  public string? StartValue { get; set; }
  public string? EndValue { get; set; }
  public string? Debug { get; set; } = "N";

  // Output parameters
  public long? SourceControlId { get; set; }
  public string? SuccessIndicator { get; set; }
  public string? MessageLog { get; set; }
}
