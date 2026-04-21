export interface JobsType {
  name: string;
  label: string;
  gradeLabel: string;
  onDuty: boolean;
  restricted?: boolean;
  active?: boolean;
  extraData?: any;
}
