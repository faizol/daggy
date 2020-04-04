/*
MIT License

Copyright (c) 2020 Mikhail Milovidov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
#include "Precompiled.h"
#include "CConsoleDaggy.h"
#include "Common.h"

#include <DaggyCore/DaggyCore.h>
#include <DaggyCore/CSsh2DataProviderFabric.h>
#include <DaggyCore/CLocalDataProvidersFabric.h>
#include <DaggyCore/CYamlDataSourcesConvertor.h>
#include <DaggyCore/CJsonDataSourcesConvertor.h>

#include "CFileDataAggregator.h"

using namespace daggycore;
using namespace daggyconv;

CConsoleDaggy::CConsoleDaggy(QObject* parent)
    : QObject(parent)
    , daggy_core_(new daggycore::DaggyCore(this))
{
    qApp->setApplicationVersion(VERSION_STR);
    qApp->setApplicationName("daggy");
    connect(this, &CConsoleDaggy::interrupt, daggy_core_, &DaggyCore::stop, Qt::QueuedConnection);
    connect(daggy_core_, &DaggyCore::stateChanged, this, [](DaggyCore::State state){
        if (state == DaggyCore::Finished)
            qApp->exit();
    });
}

daggycore::Result CConsoleDaggy::initialize()
{
    daggy_core_->createProviderFabric<CLocalDataProvidersFabric>();
#ifdef SSH2_SUPPORT
    daggy_core_->createProviderFabric<CSsh2DataProviderFabric>();
#endif

    daggy_core_->createConvertor<CJsonDataSourcesConvertor>();
#ifdef YAML_SUPPORT
    daggy_core_->createConvertor<CYamlDataSourcesConvertor>();
#endif

    const auto settings = parse();
    daggy_core_->createDataAggregator<CFileDataAggregator>(settings.output_folder, settings.data_sources_name);
    const auto result = daggy_core_->setDataSources(settings.data_source_text, settings.data_source_text_type);
    if (result && settings.timeout > 0)
        QTimer::singleShot(settings.timeout, this, &CConsoleDaggy::stop);

    return result;
}

Result CConsoleDaggy::start()
{
    return daggy_core_->start();
}

void CConsoleDaggy::stop()
{
    daggy_core_->stop();
}

bool CConsoleDaggy::handleSystemSignal(const int signal)
{
    if (signal & DEFAULT_SIGNALS) {
        emit interrupt(signal);
        return true;
    }
    return false;
}

QStringList CConsoleDaggy::supportedConvertors() const
{
    return
    {
        CJsonDataSourcesConvertor::convertor_type,
#ifdef YAML_SUPPORT
        CYamlDataSourcesConvertor::convertor_type
#endif
    };
}

QString CConsoleDaggy::textDataSourcesType(const QString& file_name) const
{
    const QString& extension = QFileInfo(file_name).suffix();
    QString result = extension;
#ifdef YAML_SUPPORT
    if (extension == "yml")
        result = CYamlDataSourcesConvertor::convertor_type;
#endif
    return result;
}

bool CConsoleDaggy::isError() const
{
    return !error_message_.isEmpty();
}

const QString& CConsoleDaggy::errorMessage() const
{
    return error_message_;
}

CConsoleDaggy::Settings CConsoleDaggy::parse() const
{
    Settings result;

    const QCommandLineOption output_folder_option({"o", "output"},
                                                  "Set output folder",
                                                  "folder", "");
    const QCommandLineOption input_format_option({"f", "format"},
                                                 "Source format",
                                                 supportedConvertors().join("|"),
                                                 CJsonDataSourcesConvertor::convertor_type);
    const QCommandLineOption auto_complete_timeout({"t", "timeout"},
                                                   "Auto complete timeout",
                                                   "time in ms",
                                                   0
                                                   );
    const QCommandLineOption input_from_stdin_option({"i", "stdin"},
                                                     "Read data aggregation sources from stdin");

    QCommandLineParser command_line_parser;
    command_line_parser.addOption(output_folder_option);
    command_line_parser.addOption(input_format_option);
    command_line_parser.addOption(input_from_stdin_option);
    command_line_parser.addOption(auto_complete_timeout);
    command_line_parser.addHelpOption();
    command_line_parser.addVersionOption();
    command_line_parser.addPositionalArgument("file", "data aggregation sources file", "*.yaml|*.yml|*.json");

    command_line_parser.process(*qApp);


    const QStringList positional_arguments = command_line_parser.positionalArguments();
    if (positional_arguments.isEmpty()) {
        command_line_parser.showHelp(-1);
    }

    const QString& source_file_name = positional_arguments.first();

    if (command_line_parser.isSet(input_from_stdin_option)) {
        result.data_source_text = QTextStream(stdin).readAll();
        result.data_sources_name = "stdin";
    }
    else {
        result.data_source_text = getTextFromFile(source_file_name);
        result.data_sources_name = QFileInfo(source_file_name).baseName();
    }

    if (command_line_parser.isSet(output_folder_option))
        result.output_folder = command_line_parser.value(output_folder_option);
    else
        result.output_folder = QString();

    if (command_line_parser.isSet(input_format_option)) {
        const QString& format = command_line_parser.value(input_format_option);
        if (format != CJsonDataSourcesConvertor::convertor_type ||
            format != CYamlDataSourcesConvertor::convertor_type)
        {
            command_line_parser.showHelp(-1);
        } else {
            result.data_source_text_type = format;
        }
    } else {
        result.data_source_text_type = textDataSourcesType(source_file_name);
    }

    if (command_line_parser.isSet(auto_complete_timeout)) {
        result.timeout = command_line_parser.value(auto_complete_timeout).toUInt();
    }

    result.data_source_text = mustache(result.data_source_text, result.output_folder);

    return result;
}

daggycore::DaggyCore* CConsoleDaggy::daggyCore() const
{
    return findChild<daggycore::DaggyCore*>();
}

QCoreApplication* CConsoleDaggy::application() const
{
    return qobject_cast<QCoreApplication*>(parent());
}

QString CConsoleDaggy::getTextFromFile(QString file_path) const
{
   QString result;
   if (!QFileInfo(file_path).exists()) {
       file_path = homeFolder() + file_path;
   }

   QFile source_file(file_path);
   if (source_file.open(QIODevice::ReadOnly | QIODevice::Text))
       result = source_file.readAll();
   else
       throw std::invalid_argument(QString("Cann't open %1 file for read: %2")
                                           .arg(file_path, source_file.errorString())
                                           .toStdString());
   if (result.isEmpty())
       throw std::invalid_argument(QString("%1 file is empty")
                                           .arg(file_path)
                                           .toStdString());

   return result;
}

QString CConsoleDaggy::homeFolder() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

QString CConsoleDaggy::mustache(const QString& text, const QString& output_folder) const
{
    QProcessEnvironment process_environment = QProcessEnvironment::systemEnvironment();
    kainjow::mustache::mustache tmpl(qUtf8Printable(text));
    kainjow::mustache::data variables;
    for (const auto& key : process_environment.keys()) {
        variables.set(qPrintable(QString("env_%1").arg(key)),
                      qUtf8Printable(process_environment.value(key)));
    }
    variables.set("output_folder", qUtf8Printable(output_folder));
    std::cout << tmpl.render(variables) << std::endl;
    return QString::fromStdString(tmpl.render(variables));
}

void CConsoleDaggy::onDaggyCoreStateChanged(int state)
{
    switch (static_cast<DaggyCore::State>(state)) {
    case daggycore::DaggyCore::NotStarted:
        break;
    case daggycore::DaggyCore::Started:
        break;
    case daggycore::DaggyCore::Finishing:
        break;
    case daggycore::DaggyCore::Finished:
        qApp->exit();
        break;
    }
}
