# installbinom
# Установка
Внимание! Установка только для CentOS!

Скрипт устанавливает и настраивает:
MySQL: 5.5.47
PHP: 5.5.30
Nginx: 1.6.3
PHPMyAdmin: 4.5.5.1
Последняя версия Ioncube и Binom

Подключаемся по SSH к серверу, заходим с пользователем root. Вводим команды по очереди.
1. yum -y install screen wget curl
2. screen -S binom (новый сеанс screen)
3. curl -o install_binom.sh https://raw.githubusercontent.com/stngrm/installbinom/master/install_binom.sh && bash install_binom.sh 2>&1 | tee binom_install.log
4. После этого начнётся установка. Потребуется ответить на 2 вопроса: имя домена, пароль для sql
5. Теперь можно отключиться от сеанса (и сервера) на 10-15 минут (зависит от мощности сервера), нажав Ctrl+a+d
6. После окончания установки будет выведено сообщение.
7. Теперь можно зайти по адресу домена и закончить установку Binom (ввести данные sql, пользователя и несколько раз нажать Next)
