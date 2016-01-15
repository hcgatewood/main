'''
CostCurve Generation Script
cost_curve_script.py
by hcgatewood

Directions:
(1) Appropriately edit the variables in the Globals class.
(2) Open the Cost Curve and Breakout wkbks, import this script and run it.
(3) To limit final call to a smaller sample: change tableRange in run function
'''

class Workbook:
    def __init__(self,fileName,correctSheet,filePath):
        self.name = fileName
        self.sheet = correctSheet
        self.path = filePath

    def set_active_wkbk(self):
        active_wkbk(self.name)
        return None

    def set_active_sheet(self):
        active_sheet(self.sheet)
        return None


class Task:
    def __init__(self,taskName,baselineCost,startDate,endDate):
        self.name = cleanup_name(taskName) + '.xlsx'
        length = endDate-startDate
        self.length = max(length.days,1)
        self.dailyCost = float(baselineCost) / self.length
        self.startDate = startDate

'''
Edit the following variables:
'''
class Globals:
    def __init__(self):
        self.costCurve = Workbook(
                'Final cost curve.xlsx', 'Cost Tracking',
                'C:\Users\huntergatewood\Desktop\Final cost curve.xlsx')
        self.breakoutData = Workbook(
                'Breakout data.xlsm', 'Project Copy (2)',
                'C:\Users\huntergatewood\Desktop\Breakout data.xlsm')

        self.generationDestination = \
                'C:\Users\huntergatewood\Desktop\Cost Curves\\'
        self.schedColumn = 1
        self.nameColumn = 2
        self.baseColumn = 8
        self.startColumn = 4
        self.endColumn = 5
        self.fileNumberStart = 1 # Starting number for first file, e.g. 001
        self.filesGenerated = 0 # Don't change this value

glo = Globals()


def create_taskList(
        tableRange='A2:H484',schedCol=glo.schedColumn,nameCol=glo.nameColumn,
        baseCol=glo.baseColumn,startCol=glo.startColumn,endCol=glo.endColumn):
    glo.breakoutData.set_active_wkbk()
    glo.breakoutData.set_active_sheet()

    # Columns-- for referencing CellRange
    schedCol,nameCol,baseCol,startCol,endCol = \
            schedCol-1,nameCol-1,baseCol-1,startCol-1,endCol-1
    taskList = []
    append_tasks(taskList,tableRange,schedCol,nameCol,baseCol,startCol,endCol)

    return taskList


def taskList_to_curve(
        taskList,rangeStart=(21,5),
        deletionRangeEnd=(21,130),dateCell='E20'):
    fileNumber = glo.fileNumberStart
    for task in taskList:
        glo.costCurve.set_active_wkbk()
        glo.costCurve.set_active_sheet()
        clear_cells(rangeStart,deletionRangeEnd)
        input_budget_values(task.length,task.dailyCost,rangeStart)
        input_startDate(dateCell,task.startDate)
        save_wkbk(fileNumber,task.name,glo.generationDestination)
        fileNumber += 1

    clear_cells(rangeStart,deletionRangeEnd)

    return None


'''
Helper functions
'''
def remove_illegals(shortName):
    illegalsList = ['<','>',':','"','/','\\','|','?','*']
    name = shortName[:]
    for illegalChar in illegalsList:
        name = name.replace(illegalChar,'')
    return name

def fix_length(shortName):
    if len(shortName) > 255:
        return shortName[:255]
    return shortName

def convert_to_camelCase(shortName):
    return shortName.title().replace(' ','')

def cleanup_name(shortName):
    return fix_length(convert_to_camelCase(remove_illegals(shortName)))

def append_tasks(
        taskList,tableRange,schedCol,nameCol,baseCol,startCol,endCol):
    for row in CellRange(tableRange).table:
        if \
                row[schedCol] == 'Auto Scheduled' or \
                type(row[baseCol]) is int and \
                row[baseCol] != 0:
            taskList.append(Task(
                    row[nameCol],row[baseCol],row[startCol],row[endCol]))
    return None

def clear_cells(rangeStart,rangeEnd):
    CellRange(rangeStart,rangeEnd).value = ''
    return None

def input_budget_values(length,dailyCost,rangeStart):
    rangeEnd = (rangeStart[0],rangeStart[1]+length-1)
    CellRange(rangeStart,rangeEnd).value = dailyCost
    return None

def input_startDate(dateCell,startDate):
    Cell(dateCell).value = startDate
    return None

def save_wkbk(fileNumber,name,generationDestination):
    wkbkName = 'CostCurve_' + str(fileNumber).zfill(3) + '_' + name
    wkbkFullPath = generationDestination + wkbkName
    save_copy(wkbkFullPath)
    glo.filesGenerated += 1

def run():
    taskList = create_taskList()
    taskList_to_curve(taskList)
    print 'Script finished.'
    print 'Files gnerated: ' + str(glo.filesGenerated) + '.'
    return None



run()