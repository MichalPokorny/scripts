import subprocess
import os
import os.path

from absl import app
from absl import logging
from absl import flags

FLAGS = flags.FLAGS

flags.DEFINE_integer('chunk', 5, 'lecture chunk size')


def wait_for_finish(processes):
    for i, (name, process) in enumerate(processes.items(), 1):
        logging.info(f'waiting for {i:02d} of {len(processes):02d}: {name}')
        process.wait()

def main(_):
    m = {
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NMAF061/1
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NMAF062/1
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NMAG162/1
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NOFY003/1
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NOFY031/1
        # TODO: https://is.mff.cuni.cz/prednasky/prednaska/NTMF111/1
        ('NDMI012', 2016, 'ZS', 'combinatorics-graphs-2'): 13,
        ('NMAF051', 2014, 'ZS', 'mathematical-analysis-1'): 23,
        ('NMAF052', 2014, 'LS', 'mathematical-analysis-2'): 27,
        ('NMAG101', 2015, 'ZS', 'linear-algebra-geometry-1'): 26,
        ('NMAG102', 2016, 'LS', 'linear-algebra-geometry-2'): 25,
        ('NMAG201', 2017, 'ZS', 'algebra-1'): 13,
        ('NMAG202', 2017, 'LS', 'algebra-2'): 13,
        ('NMAG301', 2019, 'ZS', 'commutative-rings'): 17,
        ('NMNM201', 2018, 'ZS', 'numeric-math'): 26,
        ('NOPT048', 2017, 'LS', 'optimalization-methods'): 13,
        ('NPFL122', 2019, 'ZS', 'deep-reinforcement-learning'): 10,
        ('NTIN060', 2014, 'LS', 'ads1'): 13,
        ('NTIN071', 2018, 'LS', 'automata'): 13,
    }
    # TODO: kill all processes on our death
    processes = {}
    for (code, year, semester, name), n in m.items():
        d = f'{code}-{name}'
        os.makedirs(d, exist_ok=True)
        for num in range(1, n+1):
            in_filename = f'{code}_{year}_{semester}_{num:02d}.webm'
            url = f'https://is.mff.cuni.cz/prednasky/play/s14vh2ea9emlr65v6rnd1pgn4p/{in_filename}'
            out_filename = f'{d}/{num:02d}.webm'
            processes[out_filename] = subprocess.Popen([
                'curl',
                '--output', out_filename,
                # Autoresume.
                '--continue-at', '-',
                # Disable progress bar, but do write out errors.
                '--silent', '--show-error',
                url,
            ])
            if len(processes) >= FLAGS.chunk:
                # Flush.
                wait_for_finish(processes)
                processes = {}

    wait_for_finish(processes)

if __name__ == '__main__':
    app.run(main)
